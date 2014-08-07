// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library watcher.watch_event;

/// An event describing a single change to the file system.
class WatchEvent {
  /// The manner in which the file at [path] has changed.
  final ChangeType type;

  /// The path of the file that changed.
  final String path;

  WatchEvent(this.type, this.path);

  String toString() => "$type $path";
}

/// Enum for what kind of change has happened to a file.
class ChangeType {
  /// A new file has been added.
  static const ADD = const ChangeType("add");

  /// A file has been removed.
  static const REMOVE = const ChangeType("remove");

  /// The contents of a file have changed.
  static const MODIFY = const ChangeType("modify");

  final String _name;
  const ChangeType(this._name);

  String toString() => _name;
}
