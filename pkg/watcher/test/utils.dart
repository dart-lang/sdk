// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library watcher.test.utils;

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scheduled_test/scheduled_test.dart';
import 'package:unittest/compact_vm_config.dart';
import 'package:watcher/watcher.dart';
import 'package:watcher/src/stat.dart';
import 'package:watcher/src/utils.dart';

/// The path to the temporary sandbox created for each test. All file
/// operations are implicitly relative to this directory.
String _sandboxDir;

/// The [DirectoryWatcher] being used for the current scheduled test.
DirectoryWatcher _watcher;

/// The index in [_watcher]'s event stream for the next event. When event
/// expectations are set using [expectEvent] (et. al.), they use this to
/// expect a series of events in order.
var _nextEvent = 0;

/// The mock modification times (in milliseconds since epoch) for each file.
///
/// The actual file system has pretty coarse granularity for file modification
/// times. This means using the real file system requires us to put delays in
/// the tests to ensure we wait long enough between operations for the mod time
/// to be different.
///
/// Instead, we'll just mock that out. Each time a file is written, we manually
/// increment the mod time for that file instantly.
Map<String, int> _mockFileModificationTimes;

typedef DirectoryWatcher WatcherFactory(String directory);

/// Sets the function used to create the directory watcher.
set watcherFactory(WatcherFactory factory) {
  _watcherFactory = factory;
}
WatcherFactory _watcherFactory;

void initConfig() {
  useCompactVMConfiguration();
  filterStacks = true;
}

/// Creates the sandbox directory the other functions in this library use and
/// ensures it's deleted when the test ends.
///
/// This should usually be called by [setUp].
void createSandbox() {
  var dir = Directory.systemTemp.createTempSync('watcher_test_');
  _sandboxDir = dir.path;

  _mockFileModificationTimes = new Map<String, int>();
  mockGetModificationTime((path) {
    path = p.normalize(p.relative(path, from: _sandboxDir));

    // Make sure we got a path in the sandbox.
    assert(p.isRelative(path) && !path.startsWith(".."));

    var mtime = _mockFileModificationTimes[path];
    return new DateTime.fromMillisecondsSinceEpoch(mtime == null ? 0 : mtime);
  });

  // Delete the sandbox when done.
  currentSchedule.onComplete.schedule(() {
    if (_sandboxDir != null) {
      new Directory(_sandboxDir).deleteSync(recursive: true);
      _sandboxDir = null;
    }

    _mockFileModificationTimes = null;
    mockGetModificationTime(null);
  }, "delete sandbox");
}

/// Creates a new [DirectoryWatcher] that watches a temporary directory.
///
/// Normally, this will pause the schedule until the watcher is done scanning
/// and is polling for changes. If you pass `false` for [waitForReady], it will
/// not schedule this delay.
///
/// If [dir] is provided, watches a subdirectory in the sandbox with that name.
DirectoryWatcher createWatcher({String dir, bool waitForReady}) {
  if (dir == null) {
    dir = _sandboxDir;
  } else {
    dir = p.join(_sandboxDir, dir);
  }

  var watcher = _watcherFactory(dir);

  // Wait until the scan is finished so that we don't miss changes to files
  // that could occur before the scan completes.
  if (waitForReady != false) {
    schedule(() => watcher.ready, "wait for watcher to be ready");
  }

  return watcher;
}

/// The stream of events from the watcher started with [startWatcher].
Stream _watcherEvents;

/// Creates a new [DirectoryWatcher] that watches a temporary directory and
/// starts monitoring it for events.
///
/// If [dir] is provided, watches a subdirectory in the sandbox with that name.
void startWatcher({String dir}) {
  // We want to wait until we're ready *after* we subscribe to the watcher's
  // events.
  _watcher = createWatcher(dir: dir, waitForReady: false);

  // Schedule [_watcher.events.listen] so that the watcher doesn't start
  // watching [dir] before it exists. Expose [_watcherEvents] immediately so
  // that it can be accessed synchronously after this.
  _watcherEvents = futureStream(schedule(() {
    var allEvents = new Queue();
    var subscription = _watcher.events.listen(allEvents.add,
        onError: currentSchedule.signalError);

    currentSchedule.onComplete.schedule(() {
      var numEvents = _nextEvent;
      subscription.cancel();
      _nextEvent = 0;
      _watcher = null;

      // If there are already errors, don't add this to the output and make
      // people think it might be the root cause.
      if (currentSchedule.errors.isEmpty) {
        expect(allEvents, hasLength(numEvents));
      } else {
        currentSchedule.addDebugInfo("Events fired:\n${allEvents.join('\n')}");
      }
    }, "reset watcher");

    return _watcher.events;
  }, "create watcher")).asBroadcastStream();

  schedule(() => _watcher.ready, "wait for watcher to be ready");
}

/// A future set by [inAnyOrder] that will complete to the set of events that
/// occur in the [inAnyOrder] block.
Future<Set<WatchEvent>> _unorderedEventFuture;

/// Runs [block] and allows multiple [expectEvent] calls in that block to match
/// events in any order.
void inAnyOrder(block()) {
  var oldFuture = _unorderedEventFuture;
  try {
    var firstEvent = _nextEvent;
    var completer = new Completer();
    _unorderedEventFuture = completer.future;
    block();

    _watcherEvents.skip(firstEvent).take(_nextEvent - firstEvent).toSet()
        .then(completer.complete, onError: completer.completeError);
    currentSchedule.wrapFuture(_unorderedEventFuture,
        "waiting for ${_nextEvent - firstEvent} events");
  } finally {
    _unorderedEventFuture = oldFuture;
  }
}

/// Expects that the next set of event will be a change of [type] on [path].
///
/// Multiple calls to [expectEvent] require that the events are received in that
/// order unless they're called in an [inAnyOrder] block.
void expectEvent(ChangeType type, String path) {
  var matcher = predicate((e) {
    return e is WatchEvent && e.type == type &&
        e.path == p.join(_sandboxDir, p.normalize(path));
  }, "is $type $path");

  if (_unorderedEventFuture != null) {
    // Assign this to a local variable since it will be un-assigned by the time
    // the scheduled callback runs.
    var future = _unorderedEventFuture;

    expect(
        schedule(() => future, "should fire $type event on $path"),
        completion(contains(matcher)));
  } else {
    var future = currentSchedule.wrapFuture(
        _watcherEvents.elementAt(_nextEvent),
        "waiting for $type event on $path");

    expect(
        schedule(() => future, "should fire $type event on $path"),
        completion(matcher));
  }
  _nextEvent++;
}

void expectAddEvent(String path) => expectEvent(ChangeType.ADD, path);
void expectModifyEvent(String path) => expectEvent(ChangeType.MODIFY, path);
void expectRemoveEvent(String path) => expectEvent(ChangeType.REMOVE, path);

/// Schedules writing a file in the sandbox at [path] with [contents].
///
/// If [contents] is omitted, creates an empty file. If [updatedModified] is
/// `false`, the mock file modification time is not changed.
void writeFile(String path, {String contents, bool updateModified}) {
  if (contents == null) contents = "";
  if (updateModified == null) updateModified = true;

  schedule(() {
    var fullPath = p.join(_sandboxDir, path);

    // Create any needed subdirectories.
    var dir = new Directory(p.dirname(fullPath));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    new File(fullPath).writeAsStringSync(contents);

    // Manually update the mock modification time for the file.
    if (updateModified) {
      // Make sure we always use the same separator on Windows.
      path = p.normalize(path);

      var milliseconds = _mockFileModificationTimes.putIfAbsent(path, () => 0);
      _mockFileModificationTimes[path]++;
    }
  }, "write file $path");
}

/// Schedules deleting a file in the sandbox at [path].
void deleteFile(String path) {
  schedule(() {
    new File(p.join(_sandboxDir, path)).deleteSync();
  }, "delete file $path");
}

/// Schedules renaming a file in the sandbox from [from] to [to].
///
/// If [contents] is omitted, creates an empty file.
void renameFile(String from, String to) {
  schedule(() {
    new File(p.join(_sandboxDir, from)).renameSync(p.join(_sandboxDir, to));

    // Make sure we always use the same separator on Windows.
    to = p.normalize(to);

    // Manually update the mock modification time for the file.
    var milliseconds = _mockFileModificationTimes.putIfAbsent(to, () => 0);
    _mockFileModificationTimes[to]++;
  }, "rename file $from to $to");
}

/// Schedules creating a directory in the sandbox at [path].
void createDir(String path) {
  schedule(() {
    new Directory(p.join(_sandboxDir, path)).createSync();
  }, "create directory $path");
}

/// Schedules renaming a directory in the sandbox from [from] to [to].
void renameDir(String from, String to) {
  schedule(() {
    new Directory(p.join(_sandboxDir, from))
        .renameSync(p.join(_sandboxDir, to));
  }, "rename directory $from to $to");
}

/// Schedules deleting a directory in the sandbox at [path].
void deleteDir(String path) {
  schedule(() {
    new Directory(p.join(_sandboxDir, path)).deleteSync(recursive: true);
  }, "delete directory $path");
}

/// Runs [callback] with every permutation of non-negative [i], [j], and [k]
/// less than [limit].
///
/// [limit] defaults to 3.
void withPermutations(callback(int i, int j, int k), {int limit}) {
  if (limit == null) limit = 3;
  for (var i = 0; i < limit; i++) {
    for (var j = 0; j < limit; j++) {
      for (var k = 0; k < limit; k++) {
        callback(i, j, k);
      }
    }
  }
}
