// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library watcher.directory_watcher.mac_os;

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../constructable_file_system_event.dart';
import '../path_set.dart';
import '../utils.dart';
import '../watch_event.dart';
import 'resubscribable.dart';

/// Uses the FSEvents subsystem to watch for filesystem events.
///
/// FSEvents has two main idiosyncrasies that this class works around. First, it
/// will occasionally report events that occurred before the filesystem watch
/// was initiated. Second, if multiple events happen to the same file in close
/// succession, it won't report them in the order they occurred. See issue
/// 14373.
///
/// This also works around issues 14793, 14806, and 14849 in the implementation
/// of [Directory.watch].
class MacOSDirectoryWatcher extends ResubscribableDirectoryWatcher {
  // TODO(nweiz): remove this when issue 15042 is fixed.
  static bool logDebugInfo = false;

  MacOSDirectoryWatcher(String directory)
      : super(directory, () => new _MacOSDirectoryWatcher(directory));
}

class _MacOSDirectoryWatcher implements ManuallyClosedDirectoryWatcher {
  final String directory;

  Stream<WatchEvent> get events => _eventsController.stream;
  final _eventsController = new StreamController<WatchEvent>.broadcast();

  bool get isReady => _readyCompleter.isCompleted;

  Future get ready => _readyCompleter.future;
  final _readyCompleter = new Completer();

  /// The number of event batches that have been received from
  /// [Directory.watch].
  ///
  /// This is used to determine if the [Directory.watch] stream was falsely
  /// closed due to issue 14849. A close caused by events in the past will only
  /// happen before or immediately after the first batch of events.
  int batches = 0;

  /// The set of files that are known to exist recursively within the watched
  /// directory.
  ///
  /// The state of files on the filesystem is compared against this to determine
  /// the real change that occurred when working around issue 14373. This is
  /// also used to emit REMOVE events when subdirectories are moved out of the
  /// watched directory.
  final PathSet _files;

  /// The subscription to the stream returned by [Directory.watch].
  ///
  /// This is separate from [_subscriptions] because this stream occasionally
  /// needs to be resubscribed in order to work around issue 14849.
  StreamSubscription<FileSystemEvent> _watchSubscription;

  /// A set of subscriptions that this watcher subscribes to.
  ///
  /// These are gathered together so that they may all be canceled when the
  /// watcher is closed. This does not include [_watchSubscription].
  final _subscriptions = new Set<StreamSubscription>();

  _MacOSDirectoryWatcher(String directory)
      : directory = directory,
        _files = new PathSet(directory) {
    _startWatch();

    _listen(new Directory(directory).list(recursive: true),
        (entity) {
      if (entity is! Directory) _files.add(entity.path);
    },
        onError: _emitError,
        onDone: () {
      if (MacOSDirectoryWatcher.logDebugInfo) {
        print("watcher is ready");
      }
      _readyCompleter.complete();
    },
        cancelOnError: true);
  }

  void close() {
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    if (_watchSubscription != null) _watchSubscription.cancel();
    _watchSubscription = null;
    _eventsController.close();
  }

  /// The callback that's run when [Directory.watch] emits a batch of events.
  void _onBatch(List<FileSystemEvent> batch) {
    if (MacOSDirectoryWatcher.logDebugInfo) {
      print("======== batch:");
      for (var event in batch) {
        print("  ${_formatEvent(event)}");
      }

      print("known files:");
      for (var foo in _files.toSet()) {
        print("  ${p.relative(foo, from: directory)}");
      }
    }

    batches++;

    _sortEvents(batch).forEach((path, events) {
      var relativePath = p.relative(path, from: directory);
      if (MacOSDirectoryWatcher.logDebugInfo) {
        print("events for $relativePath:\n");
        for (var event in events) {
          print("  ${_formatEvent(event)}");
        }
      }

      var canonicalEvent = _canonicalEvent(events);
      events = canonicalEvent == null ?
          _eventsBasedOnFileSystem(path) : [canonicalEvent];
      if (MacOSDirectoryWatcher.logDebugInfo) {
        print("canonical event for $relativePath: "
            "${_formatEvent(canonicalEvent)}");
        print("actionable events for $relativePath: "
            "${events.map(_formatEvent)}");
      }

      for (var event in events) {
        if (event is FileSystemCreateEvent) {
          if (!event.isDirectory) {
            _emitEvent(ChangeType.ADD, path);
            _files.add(path);
            continue;
          }

          _listen(new Directory(path).list(recursive: true), (entity) {
            if (entity is Directory) return;
            _emitEvent(ChangeType.ADD, entity.path);
            _files.add(entity.path);
          }, onError: (e, stackTrace) {
            if (MacOSDirectoryWatcher.logDebugInfo) {
              print("got error listing $relativePath: $e");
            }
            _emitError(e, stackTrace);
          }, cancelOnError: true);
        } else if (event is FileSystemModifyEvent) {
          assert(!event.isDirectory);
          _emitEvent(ChangeType.MODIFY, path);
        } else {
          assert(event is FileSystemDeleteEvent);
          for (var removedPath in _files.remove(path)) {
            _emitEvent(ChangeType.REMOVE, removedPath);
          }
        }
      }
    });

    if (MacOSDirectoryWatcher.logDebugInfo) {
      print("========");
    }
  }

  /// Sort all the events in a batch into sets based on their path.
  ///
  /// A single input event may result in multiple events in the returned map;
  /// for example, a MOVE event becomes a DELETE event for the source and a
  /// CREATE event for the destination.
  ///
  /// The returned events won't contain any [FileSystemMoveEvent]s, nor will it
  /// contain any events relating to [directory].
  Map<String, Set<FileSystemEvent>> _sortEvents(List<FileSystemEvent> batch) {
    var eventsForPaths = {};

    // FSEvents can report past events, including events on the root directory
    // such as it being created. We want to ignore these. If the directory is
    // really deleted, that's handled by [_onDone].
    batch = batch.where((event) => event.path != directory).toList();

    // Events within directories that already have events are superfluous; the
    // directory's full contents will be examined anyway, so we ignore such
    // events. Emitting them could cause useless or out-of-order events.
    var directories = unionAll(batch.map((event) {
      if (!event.isDirectory) return new Set();
      if (event is! FileSystemMoveEvent) return new Set.from([event.path]);
      return new Set.from([event.path, event.destination]);
    }));

    isInModifiedDirectory(path) =>
        directories.any((dir) => path != dir && path.startsWith(dir));

    addEvent(path, event) {
      if (isInModifiedDirectory(path)) return;
      var set = eventsForPaths.putIfAbsent(path, () => new Set());
      set.add(event);
    }

    for (var event in batch.where((event) => event is! FileSystemMoveEvent)) {
      addEvent(event.path, event);
    }

    // Issue 14806 means that move events can be misleading if they're in the
    // same batch as another modification of a related file. If they are, we
    // make the event set empty to ensure we check the state of the filesystem.
    // Otherwise, treat them as a DELETE followed by an ADD.
    for (var event in batch.where((event) => event is FileSystemMoveEvent)) {
      if (eventsForPaths.containsKey(event.path) ||
          eventsForPaths.containsKey(event.destination)) {

        if (!isInModifiedDirectory(event.path)) {
          eventsForPaths[event.path] = new Set();
        }
        if (!isInModifiedDirectory(event.destination)) {
          eventsForPaths[event.destination] = new Set();
        }

        continue;
      }

      addEvent(event.path, new ConstructableFileSystemDeleteEvent(
          event.path, event.isDirectory));
      addEvent(event.destination, new ConstructableFileSystemCreateEvent(
          event.path, event.isDirectory));
    }

    return eventsForPaths;
  }

  /// Returns the canonical event from a batch of events on the same path, if
  /// one exists.
  ///
  /// If [batch] doesn't contain any contradictory events (e.g. DELETE and
  /// CREATE, or events with different values for [isDirectory]), this returns a
  /// single event that describes what happened to the path in question.
  ///
  /// If [batch] does contain contradictory events, this returns `null` to
  /// indicate that the state of the path on the filesystem should be checked to
  /// determine what occurred.
  FileSystemEvent _canonicalEvent(Set<FileSystemEvent> batch) {
    // An empty batch indicates that we've learned earlier that the batch is
    // contradictory (e.g. because of a move).
    if (batch.isEmpty) return null;

    var type = batch.first.type;
    var isDir = batch.first.isDirectory;

    for (var event in batch.skip(1)) {
      // If one event reports that the file is a directory and another event
      // doesn't, that's a contradiction.
      if (isDir != event.isDirectory) return null;

      // Modify events don't contradict either CREATE or REMOVE events. We can
      // safely assume the file was modified after a CREATE or before the
      // REMOVE; otherwise there will also be a REMOVE or CREATE event
      // (respectively) that will be contradictory.
      if (event is FileSystemModifyEvent) continue;
      assert(event is FileSystemCreateEvent || event is FileSystemDeleteEvent);

      // If we previously thought this was a MODIFY, we now consider it to be a
      // CREATE or REMOVE event. This is safe for the same reason as above.
      if (type == FileSystemEvent.MODIFY) {
        type = event.type;
        continue;
      }

      // A CREATE event contradicts a REMOVE event and vice versa.
      assert(type == FileSystemEvent.CREATE || type == FileSystemEvent.DELETE);
      if (type != event.type) return null;
    }

    switch (type) {
      case FileSystemEvent.CREATE:
        // Issue 14793 means that CREATE events can actually mean DELETE, so we
        // should always check the filesystem for them.
        return null;
      case FileSystemEvent.DELETE:
        return new ConstructableFileSystemDeleteEvent(batch.first.path, isDir);
      case FileSystemEvent.MODIFY:
        return new ConstructableFileSystemModifyEvent(
            batch.first.path, isDir, false);
      default: assert(false);
    }
  }

  /// Returns one or more events that describe the change between the last known
  /// state of [path] and its current state on the filesystem.
  ///
  /// This returns a list whose order should be reflected in the events emitted
  /// to the user, unlike the batched events from [Directory.watch]. The
  /// returned list may be empty, indicating that no changes occurred to [path]
  /// (probably indicating that it was created and then immediately deleted).
  List<FileSystemEvent> _eventsBasedOnFileSystem(String path) {
    var fileExisted = _files.contains(path);
    var dirExisted = _files.containsDir(path);
    var fileExists = new File(path).existsSync();
    var dirExists = new Directory(path).existsSync();

    if (MacOSDirectoryWatcher.logDebugInfo) {
      print("file existed: $fileExisted");
      print("dir existed: $dirExisted");
      print("file exists: $fileExists");
      print("dir exists: $dirExists");
    }

    var events = [];
    if (fileExisted) {
      if (fileExists) {
        events.add(new ConstructableFileSystemModifyEvent(path, false, false));
      } else {
        events.add(new ConstructableFileSystemDeleteEvent(path, false));
      }
    } else if (dirExisted) {
      if (dirExists) {
        // If we got contradictory events for a directory that used to exist and
        // still exists, we need to rescan the whole thing in case it was
        // replaced with a different directory.
        events.add(new ConstructableFileSystemDeleteEvent(path, true));
        events.add(new ConstructableFileSystemCreateEvent(path, true));
      } else {
        events.add(new ConstructableFileSystemDeleteEvent(path, true));
      }
    }

    if (!fileExisted && fileExists) {
      events.add(new ConstructableFileSystemCreateEvent(path, false));
    } else if (!dirExisted && dirExists) {
      events.add(new ConstructableFileSystemCreateEvent(path, true));
    }

    return events;
  }

  /// The callback that's run when the [Directory.watch] stream is closed.
  void _onDone() {
    _watchSubscription = null;

    // If the directory still exists and we haven't seen more than one batch,
    // this is probably issue 14849 rather than a real close event. We should
    // just restart the watcher.
    if (batches < 2 && new Directory(directory).existsSync()) {
      _startWatch();
      return;
    }

    // FSEvents can fail to report the contents of the directory being removed
    // when the directory itself is removed, so we need to manually mark the as
    // removed.
    for (var file in _files.toSet()) {
      _emitEvent(ChangeType.REMOVE, file);
    }
    _files.clear();
    close();
  }

  /// Start or restart the underlying [Directory.watch] stream.
  void _startWatch() {
    // Batch the FSEvent changes together so that we can dedup events.
    var innerStream = new Directory(directory).watch(recursive: true).transform(
        new BatchedStreamTransformer<FileSystemEvent>());
    _watchSubscription = innerStream.listen(_onBatch,
        onError: _eventsController.addError,
        onDone: _onDone);
  }

  /// Emit an event with the given [type] and [path].
  void _emitEvent(ChangeType type, String path) {
    if (!isReady) return;

    // Don't emit ADD events for files that we already know about. Such an event
    // probably comes from FSEvents reporting an add that happened prior to the
    // watch beginning.
    if (type == ChangeType.ADD && _files.contains(path)) return;

    if (MacOSDirectoryWatcher.logDebugInfo) {
      print("emitting $type ${p.relative(path, from: directory)}");
    }

    _eventsController.add(new WatchEvent(type, path));
  }

  /// Emit an error, then close the watcher.
  void _emitError(error, StackTrace stackTrace) {
    _eventsController.addError(error, stackTrace);
    close();
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

  // TODO(nweiz): remove this when issue 15042 is fixed.
  /// Return a human-friendly string representation of [event].
  String _formatEvent(FileSystemEvent event) {
    if (event == null) return 'null';

    var path = p.relative(event.path, from: directory);
    var type = event.isDirectory ? 'directory' : 'file';
    if (event is FileSystemCreateEvent) {
      return "create $type $path";
    } else if (event is FileSystemDeleteEvent) {
      return "delete $type $path";
    } else if (event is FileSystemModifyEvent) {
      return "modify $type $path";
    } else if (event is FileSystemMoveEvent) {
      return "move $type $path to "
          "${p.relative(event.destination, from: directory)}";
    }
  }
}
