// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library watcher.directory_watcher.mac_os;

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:stack_trace/stack_trace.dart';

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
/// This also works around issues 16003 and 14849 in the implementation of
/// [Directory.watch].
class MacOSDirectoryWatcher extends ResubscribableDirectoryWatcher {
  // TODO(nweiz): remove these when issue 15042 is fixed.
  static var logDebugInfo = false;
  static var _count = 0;

  MacOSDirectoryWatcher(String directory)
      : super(directory, () => new _MacOSDirectoryWatcher(directory, _count++));
}

class _MacOSDirectoryWatcher implements ManuallyClosedDirectoryWatcher {
  // TODO(nweiz): remove these when issue 15042 is fixed.
  static var _count = 0;
  final String _id;

  final String directory;

  Stream<WatchEvent> get events => _eventsController.stream;
  final _eventsController = new StreamController<WatchEvent>.broadcast();

  bool get isReady => _readyCompleter.isCompleted;

  Future get ready => _readyCompleter.future;
  final _readyCompleter = new Completer();

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

  /// The subscription to the [Directory.list] call for the initial listing of
  /// the directory to determine its initial state.
  StreamSubscription<FileSystemEntity> _initialListSubscription;

  /// The subscription to the [Directory.list] call for listing the contents of
  /// a subdirectory that was moved into the watched directory.
  StreamSubscription<FileSystemEntity> _listSubscription;

  /// The timer for tracking how long we wait for an initial batch of bogus
  /// events (see issue 14373).
  Timer _bogusEventTimer;

  _MacOSDirectoryWatcher(String directory, int parentId)
      : directory = directory,
        _files = new PathSet(directory),
        _id = "$parentId/${_count++}" {
    _startWatch();

    // Before we're ready to emit events, wait for [_listDir] to complete and
    // for enough time to elapse that if bogus events (issue 14373) would be
    // emitted, they will be.
    //
    // If we do receive a batch of events, [_onBatch] will ensure that these
    // futures don't fire and that the directory is re-listed.
    Future.wait([
      _listDir().then((_) {
        if (MacOSDirectoryWatcher.logDebugInfo) {
          print("[$_id] finished initial directory list");
        }
      }),
      _waitForBogusEvents()
    ]).then((_) {
      if (MacOSDirectoryWatcher.logDebugInfo) {
        print("[$_id] watcher is ready, known files:");
        for (var file in _files.toSet()) {
          print("[$_id]   ${p.relative(file, from: directory)}");
        }
      }
      _readyCompleter.complete();
    });
  }

  void close() {
    if (MacOSDirectoryWatcher.logDebugInfo) {
      print("[$_id] watcher is closed\n${new Chain.current().terse}");
    }
    if (_watchSubscription != null) _watchSubscription.cancel();
    if (_initialListSubscription != null) _initialListSubscription.cancel();
    if (_listSubscription != null) _listSubscription.cancel();
    _watchSubscription = null;
    _initialListSubscription = null;
    _listSubscription = null;
    _eventsController.close();
  }

  /// The callback that's run when [Directory.watch] emits a batch of events.
  void _onBatch(List<FileSystemEvent> batch) {
    if (MacOSDirectoryWatcher.logDebugInfo) {
      print("[$_id] ======== batch:");
      for (var event in batch) {
        print("[$_id]   ${_formatEvent(event)}");
      }

      print("[$_id] known files:");
      for (var file in _files.toSet()) {
        print("[$_id]   ${p.relative(file, from: directory)}");
      }
    }

    // If we get a batch of events before we're ready to begin emitting events,
    // it's probable that it's a batch of pre-watcher events (see issue 14373).
    // Ignore those events and re-list the directory.
    if (!isReady) {
      if (MacOSDirectoryWatcher.logDebugInfo) {
        print("[$_id] not ready to emit events, re-listing directory");
      }

      // Cancel the timer because bogus events only occur in the first batch, so
      // we can fire [ready] as soon as we're done listing the directory.
      _bogusEventTimer.cancel();
      _listDir().then((_) {
        if (MacOSDirectoryWatcher.logDebugInfo) {
          print("[$_id] watcher is ready, known files:");
          for (var file in _files.toSet()) {
            print("[$_id]   ${p.relative(file, from: directory)}");
          }
        }
        _readyCompleter.complete();
      });
      return;
    }

    _sortEvents(batch).forEach((path, events) {
      var relativePath = p.relative(path, from: directory);
      if (MacOSDirectoryWatcher.logDebugInfo) {
        print("[$_id] events for $relativePath:");
        for (var event in events) {
          print("[$_id]   ${_formatEvent(event)}");
        }
      }

      var canonicalEvent = _canonicalEvent(events);
      events = canonicalEvent == null ?
          _eventsBasedOnFileSystem(path) : [canonicalEvent];
      if (MacOSDirectoryWatcher.logDebugInfo) {
        print("[$_id] canonical event for $relativePath: "
            "${_formatEvent(canonicalEvent)}");
        print("[$_id] actionable events for $relativePath: "
            "${events.map(_formatEvent)}");
      }

      for (var event in events) {
        if (event is FileSystemCreateEvent) {
          if (!event.isDirectory) {
            // Don't emit ADD events for files or directories that we already
            // know about. Such an event comes from FSEvents reporting an add
            // that happened prior to the watch beginning.
            if (_files.contains(path)) continue;

            _emitEvent(ChangeType.ADD, path);
            _files.add(path);
            continue;
          }

          if (_files.containsDir(path)) continue;

          var stream = Chain.track(new Directory(path).list(recursive: true));
          _listSubscription = stream.listen((entity) {
            if (entity is Directory) return;
            if (_files.contains(path)) return;

            _emitEvent(ChangeType.ADD, entity.path);
            _files.add(entity.path);
          }, onError: (e, stackTrace) {
            if (MacOSDirectoryWatcher.logDebugInfo) {
              print("[$_id] got error listing $relativePath: $e");
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
      print("[$_id] ======== batch complete");
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

    for (var event in batch) {
      // The Mac OS watcher doesn't emit move events. See issue 14806.
      assert(event is! FileSystemMoveEvent);
      addEvent(event.path, event);
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
    var hadModifyEvent = false;

    for (var event in batch.skip(1)) {
      // If one event reports that the file is a directory and another event
      // doesn't, that's a contradiction.
      if (isDir != event.isDirectory) return null;

      // Modify events don't contradict either CREATE or REMOVE events. We can
      // safely assume the file was modified after a CREATE or before the
      // REMOVE; otherwise there will also be a REMOVE or CREATE event
      // (respectively) that will be contradictory.
      if (event is FileSystemModifyEvent) {
        hadModifyEvent = true;
        continue;
      }
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

    // If we got a CREATE event for a file we already knew about, that comes
    // from FSEvents reporting an add that happened prior to the watch
    // beginning. If we also received a MODIFY event, we want to report that,
    // but not the CREATE.
    if (type == FileSystemEvent.CREATE && hadModifyEvent &&
        _files.contains(batch.first.path)) {
      type = FileSystemEvent.MODIFY;
    }

    switch (type) {
      case FileSystemEvent.CREATE:
        // Issue 16003 means that a CREATE event for a directory can indicate
        // that the directory was moved and then re-created.
        // [_eventsBasedOnFileSystem] will handle this correctly by producing a
        // DELETE event followed by a CREATE event if the directory exists.
        if (isDir) return null;
        return new ConstructableFileSystemCreateEvent(batch.first.path, false);
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
      print("[$_id] checking file system for "
          "${p.relative(path, from: directory)}");
      print("[$_id]   file existed: $fileExisted");
      print("[$_id]   dir existed: $dirExisted");
      print("[$_id]   file exists: $fileExists");
      print("[$_id]   dir exists: $dirExists");
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
    if (MacOSDirectoryWatcher.logDebugInfo) print("[$_id] stream closed");

    _watchSubscription = null;

    // If the directory still exists and we're still expecting bogus events,
    // this is probably issue 14849 rather than a real close event. We should
    // just restart the watcher.
    if (!isReady && new Directory(directory).existsSync()) {
      if (MacOSDirectoryWatcher.logDebugInfo) {
        print("[$_id] fake closure (issue 14849), re-opening stream");
      }
      _startWatch();
      return;
    }

    // FSEvents can fail to report the contents of the directory being removed
    // when the directory itself is removed, so we need to manually mark the
    // files as removed.
    for (var file in _files.toSet()) {
      _emitEvent(ChangeType.REMOVE, file);
    }
    _files.clear();
    close();
  }

  /// Start or restart the underlying [Directory.watch] stream.
  void _startWatch() {
    // Batch the FSEvent changes together so that we can dedup events.
    var innerStream =
        Chain.track(new Directory(directory).watch(recursive: true))
        .transform(new BatchedStreamTransformer<FileSystemEvent>());
    _watchSubscription = innerStream.listen(_onBatch,
        onError: _eventsController.addError,
        onDone: _onDone);
  }

  /// Starts or restarts listing the watched directory to get an initial picture
  /// of its state.
  Future _listDir() {
    assert(!isReady);
    if (_initialListSubscription != null) _initialListSubscription.cancel();

    _files.clear();
    var completer = new Completer();
    var stream = Chain.track(new Directory(directory).list(recursive: true));
    _initialListSubscription = stream.listen((entity) {
      if (entity is! Directory) _files.add(entity.path);
    },
        onError: _emitError,
        onDone: completer.complete,
        cancelOnError: true);
    return completer.future;
  }

  /// Wait 200ms for a batch of bogus events (issue 14373) to come in.
  ///
  /// 200ms is short in terms of human interaction, but longer than any Mac OS
  /// watcher tests take on the bots, so it should be safe to assume that any
  /// bogus events will be signaled in that time frame.
  Future _waitForBogusEvents() {
    var completer = new Completer();
    _bogusEventTimer = new Timer(
        new Duration(milliseconds: 200),
        completer.complete);
    return completer.future;
  }

  /// Emit an event with the given [type] and [path].
  void _emitEvent(ChangeType type, String path) {
    if (!isReady) return;

    if (MacOSDirectoryWatcher.logDebugInfo) {
      print("[$_id] emitting $type ${p.relative(path, from: directory)}");
    }

    _eventsController.add(new WatchEvent(type, path));
  }

  /// Emit an error, then close the watcher.
  void _emitError(error, StackTrace stackTrace) {
    if (MacOSDirectoryWatcher.logDebugInfo) {
      print("[$_id] emitting error: $error\n" +
          "${new Chain.forTrace(stackTrace).terse}");
    }
    _eventsController.addError(error, stackTrace);
    close();
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
