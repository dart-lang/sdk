// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library watcher.directory_watcher;

import 'dart:async';
import 'dart:io';

import 'watch_event.dart';
import 'directory_watcher/linux.dart';
import 'directory_watcher/mac_os.dart';
import 'directory_watcher/windows.dart';
import 'directory_watcher/polling.dart';

/// Watches the contents of a directory and emits [WatchEvent]s when something
/// in the directory has changed.
abstract class DirectoryWatcher {
  /// The directory whose contents are being monitored.
  String get directory;

  /// The broadcast [Stream] of events that have occurred to files in
  /// [directory].
  ///
  /// Changes will only be monitored while this stream has subscribers. Any
  /// file changes that occur during periods when there are no subscribers
  /// will not be reported the next time a subscriber is added.
  Stream<WatchEvent> get events;

  /// Whether the watcher is initialized and watching for file changes.
  ///
  /// This is true if and only if [ready] is complete.
  bool get isReady;

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
  Future get ready;

  /// Creates a new [DirectoryWatcher] monitoring [directory].
  ///
  /// If a native directory watcher is available for this platform, this will
  /// use it. Otherwise, it will fall back to a [PollingDirectoryWatcher].
  ///
  /// If [_pollingDelay] is passed, it specifies the amount of time the watcher
  /// will pause between successive polls of the directory contents. Making this
  /// shorter will give more immediate feedback at the expense of doing more IO
  /// and higher CPU usage. Defaults to one second. Ignored for non-polling
  /// watchers.
  factory DirectoryWatcher(String directory, {Duration pollingDelay}) {
    if (Platform.isLinux) return new LinuxDirectoryWatcher(directory);
    if (Platform.isMacOS) return new MacOSDirectoryWatcher(directory);
    if (Platform.isWindows) return new WindowsDirectoryWatcher(directory);
    return new PollingDirectoryWatcher(directory, pollingDelay: pollingDelay);
  }
}
