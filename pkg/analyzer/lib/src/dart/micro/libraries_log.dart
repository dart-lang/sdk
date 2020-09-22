// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

class ChangeFileLoadEntry extends LibrariesLogEntry {
  /// The path of the file that was reported as changed.
  final String target;

  /// The files that depend transitively on the [target]. These files are
  /// removed from the state, and from the element factory.
  final List<LibrariesLogFile> removed = [];

  ChangeFileLoadEntry._(this.target);

  void addRemoved({
    @required String path,
    @required Uri uri,
  }) {
    removed.add(
      LibrariesLogFile._(path, uri),
    );
  }

  @override
  String toString() {
    return 'Change(target: $target, removed: $removed)';
  }
}

class LibrariesLog {
  final List<LibrariesLogEntry> entries = [];

  ChangeFileLoadEntry changeFile(String path) {
    var entry = ChangeFileLoadEntry._(path);
    entries.add(entry);
    return entry;
  }

  LoadLibrariesForTargetLogEntry loadForTarget({
    @required String path,
    @required Uri uri,
  }) {
    var entry = LoadLibrariesForTargetLogEntry._(
      LibrariesLogFile._(path, uri),
    );
    entries.add(entry);
    return entry;
  }
}

abstract class LibrariesLogEntry {
  final DateTime time = DateTime.now();
}

class LibrariesLogFile {
  final String path;
  final Uri uri;

  LibrariesLogFile._(this.path, this.uri);

  @override
  String toString() {
    return '(path: $path, uri: $uri)';
  }
}

class LoadLibrariesForTargetLogEntry extends LibrariesLogEntry {
  final LibrariesLogFile target;
  final List<LibrariesLogFile> loaded = [];

  LoadLibrariesForTargetLogEntry._(this.target);

  void addLibrary({
    @required String path,
    @required Uri uri,
  }) {
    loaded.add(
      LibrariesLogFile._(path, uri),
    );
  }

  @override
  String toString() {
    return 'Load(target: $target, loaded: $loaded)';
  }
}
