// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library watcher.test.utils;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scheduled_test/scheduled_stream.dart';
import 'package:scheduled_test/scheduled_test.dart';
import 'package:unittest/compact_vm_config.dart';
import 'package:watcher/watcher.dart';
import 'package:watcher/src/stat.dart';
import 'package:watcher/src/utils.dart';

// TODO(nweiz): remove this when issue 15042 is fixed.
import 'package:watcher/src/directory_watcher/mac_os.dart';

/// The path to the temporary sandbox created for each test. All file
/// operations are implicitly relative to this directory.
String _sandboxDir;

/// The [DirectoryWatcher] being used for the current scheduled test.
DirectoryWatcher _watcher;

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
      // TODO(rnystrom): Issue 19155. The watcher should already be closed when
      // we clean up the sandbox.
      if (_watcherEvents != null) {
        _watcherEvents.close();
      }
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
ScheduledStream<WatchEvent> _watcherEvents;

/// Creates a new [DirectoryWatcher] that watches a temporary directory and
/// starts monitoring it for events.
///
/// If [dir] is provided, watches a subdirectory in the sandbox with that name.
void startWatcher({String dir}) {
  var testCase = currentTestCase.description;
  if (MacOSDirectoryWatcher.logDebugInfo) {
    print("starting watcher for $testCase (${new DateTime.now()})");
  }

  // We want to wait until we're ready *after* we subscribe to the watcher's
  // events.
  _watcher = createWatcher(dir: dir, waitForReady: false);

  // Schedule [_watcher.events.listen] so that the watcher doesn't start
  // watching [dir] before it exists. Expose [_watcherEvents] immediately so
  // that it can be accessed synchronously after this.
  _watcherEvents = new ScheduledStream(futureStream(schedule(() {
    currentSchedule.onComplete.schedule(() {
      if (MacOSDirectoryWatcher.logDebugInfo) {
        print("stopping watcher for $testCase (${new DateTime.now()})");
      }

      _watcher = null;
      if (!_closePending) _watcherEvents.close();

      // If there are already errors, don't add this to the output and make
      // people think it might be the root cause.
      if (currentSchedule.errors.isEmpty) {
        _watcherEvents.expect(isDone);
      }
    }, "reset watcher");

    return _watcher.events;
  }, "create watcher"), broadcast: true));

  schedule(() => _watcher.ready, "wait for watcher to be ready");
}

/// Whether an event to close [_watcherEvents] has been scheduled.
bool _closePending = false;

/// Schedule closing the directory watcher stream after the event queue has been
/// pumped.
///
/// This is necessary when events are allowed to occur, but don't have to occur,
/// at the end of a test. Otherwise, if they don't occur, the test will wait
/// indefinitely because they might in the future and because the watcher is
/// normally only closed after the test completes.
void startClosingEventStream() {
  schedule(() {
    _closePending = true;
    pumpEventQueue().then((_) => _watcherEvents.close()).whenComplete(() {
      _closePending = false;
    });
  }, 'start closing event stream');
}

/// A list of [StreamMatcher]s that have been collected using
/// [_collectStreamMatcher].
List<StreamMatcher> _collectedStreamMatchers;

/// Collects all stream matchers that are registered within [block] into a
/// single stream matcher.
///
/// The returned matcher will match each of the collected matchers in order.
StreamMatcher _collectStreamMatcher(block()) {
  var oldStreamMatchers = _collectedStreamMatchers;
  _collectedStreamMatchers = new List<StreamMatcher>();
  try {
    block();
    return inOrder(_collectedStreamMatchers);
  } finally {
    _collectedStreamMatchers = oldStreamMatchers;
  }
}

/// Either add [streamMatcher] as an expectation to [_watcherEvents], or collect
/// it with [_collectStreamMatcher].
///
/// [streamMatcher] can be a [StreamMatcher], a [Matcher], or a value.
void _expectOrCollect(streamMatcher) {
  if (_collectedStreamMatchers != null) {
    _collectedStreamMatchers.add(new StreamMatcher.wrap(streamMatcher));
  } else {
    _watcherEvents.expect(streamMatcher);
  }
}

/// Expects that [matchers] will match emitted events in any order.
///
/// [matchers] may be [Matcher]s or values, but not [StreamMatcher]s.
void inAnyOrder(Iterable matchers) {
  matchers = matchers.toSet();
  _expectOrCollect(nextValues(matchers.length, unorderedMatches(matchers)));
}

/// Expects that the expectations established in either [block1] or [block2]
/// will match the emitted events.
///
/// If both blocks match, the one that consumed more events will be used.
void allowEither(block1(), block2()) {
  _expectOrCollect(either(
      _collectStreamMatcher(block1), _collectStreamMatcher(block2)));
}

/// Allows the expectations established in [block] to match the emitted events.
///
/// If the expectations in [block] don't match, no error will be raised and no
/// events will be consumed. If this is used at the end of a test,
/// [startClosingEventStream] should be called before it.
void allowEvents(block()) {
  _expectOrCollect(allow(_collectStreamMatcher(block)));
}

/// Returns a matcher that matches a [WatchEvent] with the given [type] and
/// [path].
Matcher isWatchEvent(ChangeType type, String path) {
  return predicate((e) {
    return e is WatchEvent && e.type == type &&
        e.path == p.join(_sandboxDir, p.normalize(path));
  }, "is $type $path");
}

/// Returns a [Matcher] that matches a [WatchEvent] for an add event for [path].
Matcher isAddEvent(String path) => isWatchEvent(ChangeType.ADD, path);

/// Returns a [Matcher] that matches a [WatchEvent] for a modification event for
/// [path].
Matcher isModifyEvent(String path) => isWatchEvent(ChangeType.MODIFY, path);

/// Returns a [Matcher] that matches a [WatchEvent] for a removal event for
/// [path].
Matcher isRemoveEvent(String path) => isWatchEvent(ChangeType.REMOVE, path);

/// Expects that the next event emitted will be for an add event for [path].
void expectAddEvent(String path) =>
    _expectOrCollect(isWatchEvent(ChangeType.ADD, path));

/// Expects that the next event emitted will be for a modification event for
/// [path].
void expectModifyEvent(String path) =>
    _expectOrCollect(isWatchEvent(ChangeType.MODIFY, path));

/// Expects that the next event emitted will be for a removal event for [path].
void expectRemoveEvent(String path) =>
    _expectOrCollect(isWatchEvent(ChangeType.REMOVE, path));

/// Consumes an add event for [path] if one is emitted at this point in the
/// schedule, but doesn't throw an error if it isn't.
///
/// If this is used at the end of a test, [startClosingEventStream] should be
/// called before it.
void allowAddEvent(String path) =>
    _expectOrCollect(allow(isWatchEvent(ChangeType.ADD, path)));

/// Consumes a modification event for [path] if one is emitted at this point in
/// the schedule, but doesn't throw an error if it isn't.
///
/// If this is used at the end of a test, [startClosingEventStream] should be
/// called before it.
void allowModifyEvent(String path) =>
    _expectOrCollect(allow(isWatchEvent(ChangeType.MODIFY, path)));

/// Consumes a removal event for [path] if one is emitted at this point in the
/// schedule, but doesn't throw an error if it isn't.
///
/// If this is used at the end of a test, [startClosingEventStream] should be
/// called before it.
void allowRemoveEvent(String path) =>
    _expectOrCollect(allow(isWatchEvent(ChangeType.REMOVE, path)));

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

    if (MacOSDirectoryWatcher.logDebugInfo) {
      print("[test] writing file $path");
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
    if (MacOSDirectoryWatcher.logDebugInfo) {
      print("[test] deleting file $path");
    }
    new File(p.join(_sandboxDir, path)).deleteSync();
  }, "delete file $path");
}

/// Schedules renaming a file in the sandbox from [from] to [to].
///
/// If [contents] is omitted, creates an empty file.
void renameFile(String from, String to) {
  schedule(() {
    if (MacOSDirectoryWatcher.logDebugInfo) {
      print("[test] renaming file $from to $to");
    }

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
    if (MacOSDirectoryWatcher.logDebugInfo) {
      print("[test] creating directory $path");
    }
    new Directory(p.join(_sandboxDir, path)).createSync();
  }, "create directory $path");
}

/// Schedules renaming a directory in the sandbox from [from] to [to].
void renameDir(String from, String to) {
  schedule(() {
    if (MacOSDirectoryWatcher.logDebugInfo) {
      print("[test] renaming directory $from to $to");
    }
    new Directory(p.join(_sandboxDir, from))
        .renameSync(p.join(_sandboxDir, to));
  }, "rename directory $from to $to");
}

/// Schedules deleting a directory in the sandbox at [path].
void deleteDir(String path) {
  schedule(() {
    if (MacOSDirectoryWatcher.logDebugInfo) {
      print("[test] deleting directory $path");
    }
    new Directory(p.join(_sandboxDir, path)).deleteSync(recursive: true);
  }, "delete directory $path");
}

/// Runs [callback] with every permutation of non-negative [i], [j], and [k]
/// less than [limit].
///
/// Returns a set of all values returns by [callback].
///
/// [limit] defaults to 3.
Set withPermutations(callback(int i, int j, int k), {int limit}) {
  if (limit == null) limit = 3;
  var results = new Set();
  for (var i = 0; i < limit; i++) {
    for (var j = 0; j < limit; j++) {
      for (var k = 0; k < limit; k++) {
        results.add(callback(i, j, k));
      }
    }
  }
  return results;
}
