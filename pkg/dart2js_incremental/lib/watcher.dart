// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js_incremental.watcher;

import 'dart:io';

import 'dart:async';

class Watcher {
  final Set<String> _watchedDirectories = new Set<String>();

  final Map<String, Set<Uri>> _watchedFiles = new Map<String, Set<Uri>>();

  final Set<Uri> _changes = new Set<Uri>();

  bool _hasEarlyChanges = false;

  Completer<bool> _changesCompleter;

  Future<bool> hasChanges() {
    if (_changesCompleter == null && _hasEarlyChanges) {
      return new Future.value(true);
    }
    _changesCompleter = new Completer<bool>();
    return _changesCompleter.future;
  }

  void _onFileSystemEvent(FileSystemEvent event) {
    Set<Uri> uris = _watchedFiles[event.path];
    if (uris == null) return;
    _changes.addAll(uris);
    if (_changesCompleter == null) {
      _hasEarlyChanges = true;
    } else if (!_changesCompleter.isCompleted) {
      _changesCompleter.complete(true);
    }
  }

  Map<Uri, Uri> readChanges() {
    if (_changes.isEmpty) {
      throw new StateError("No changes");
    }
    Map<Uri, Uri> result = new Map<Uri, Uri>();
    for (Uri uri in _changes) {
      result[uri] = uri;
    }
    _changes.clear();
    return result;
  }

  void watchFile(Uri uri) {
    String realpath = new File.fromUri(uri).resolveSymbolicLinksSync();
    _watchedFiles.putIfAbsent(realpath, () => new Set<Uri>()).add(uri);
    Directory directory = new File(realpath).parent;
    if (_watchedDirectories.add(directory.path)) {
      print("Watching ${directory.path}");
      directory.watch().listen(_onFileSystemEvent);
    }
  }
}
