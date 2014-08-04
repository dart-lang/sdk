// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library watcher.constructable_file_system_event;

import 'dart:io';

abstract class _ConstructableFileSystemEvent implements FileSystemEvent {
  final bool isDirectory;
  final String path;
  int get type;

  _ConstructableFileSystemEvent(this.path, this.isDirectory);
}

class ConstructableFileSystemCreateEvent extends _ConstructableFileSystemEvent
    implements FileSystemCreateEvent {
  final type = FileSystemEvent.CREATE;

  ConstructableFileSystemCreateEvent(String path, bool isDirectory)
      : super(path, isDirectory);

  String toString() => "FileSystemCreateEvent('$path')";
}

class ConstructableFileSystemDeleteEvent extends _ConstructableFileSystemEvent
    implements FileSystemDeleteEvent {
  final type = FileSystemEvent.DELETE;

  ConstructableFileSystemDeleteEvent(String path, bool isDirectory)
      : super(path, isDirectory);

  String toString() => "FileSystemDeleteEvent('$path')";
}

class ConstructableFileSystemModifyEvent extends _ConstructableFileSystemEvent
    implements FileSystemModifyEvent {
  final bool contentChanged;
  final type = FileSystemEvent.MODIFY;

  ConstructableFileSystemModifyEvent(String path, bool isDirectory,
      this.contentChanged)
      : super(path, isDirectory);

  String toString() =>
      "FileSystemModifyEvent('$path', contentChanged=$contentChanged)";
}

class ConstructableFileSystemMoveEvent extends _ConstructableFileSystemEvent
    implements FileSystemMoveEvent {
  final String destination;
  final type = FileSystemEvent.MOVE;

  ConstructableFileSystemMoveEvent(String path, bool isDirectory,
      this.destination)
      : super(path, isDirectory);

  String toString() => "FileSystemMoveEvent('$path', '$destination')";
}
