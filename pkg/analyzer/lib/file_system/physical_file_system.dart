// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library physical_file_system;

import 'dart:async';
import 'dart:io' as io;

import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:path/path.dart';
import 'package:watcher/watcher.dart';

import 'file_system.dart';


/**
 * A `dart:io` based implementation of [ResourceProvider].
 */
class PhysicalResourceProvider implements ResourceProvider {
  static final PhysicalResourceProvider INSTANCE =
      new PhysicalResourceProvider._();

  PhysicalResourceProvider._();

  @override
  Context get pathContext => io.Platform.isWindows ? windows : posix;

  @override
  Resource getResource(String path) {
    if (io.FileSystemEntity.isDirectorySync(path)) {
      io.Directory directory = new io.Directory(path);
      return new _PhysicalFolder(directory);
    } else {
      io.File file = new io.File(path);
      return new _PhysicalFile(file);
    }
  }
}


/**
 * A `dart:io` based implementation of [File].
 */
class _PhysicalFile extends _PhysicalResource implements File {
  _PhysicalFile(io.File file) : super(file);

  @override
  Source createSource([Uri uri]) {
    io.File file = _entry as io.File;
    JavaFile javaFile = new JavaFile(file.absolute.path);
    if (uri == null) {
      uri = javaFile.toURI();
    }
    return new FileBasedSource.con2(uri, javaFile);
  }

  @override
  bool isOrContains(String path) {
    return path == this.path;
  }
}


/**
 * A `dart:io` based implementation of [Folder].
 */
class _PhysicalFolder extends _PhysicalResource implements Folder {
  _PhysicalFolder(io.Directory directory) : super(directory);

  @override
  Stream<WatchEvent> get changes => new DirectoryWatcher(_entry.path).events;

  @override
  String canonicalizePath(String relPath) {
    return normalize(join(_entry.absolute.path, relPath));
  }

  @override
  bool contains(String path) {
    return isWithin(this.path, path);
  }

  @override
  Resource getChild(String relPath) {
    String canonicalPath = canonicalizePath(relPath);
    return PhysicalResourceProvider.INSTANCE.getResource(canonicalPath);
  }

  @override
  List<Resource> getChildren() {
    List<Resource> children = <Resource>[];
    io.Directory directory = _entry as io.Directory;
    List<io.FileSystemEntity> entries = directory.listSync(recursive: false);
    int numEntries = entries.length;
    for (int i = 0; i < numEntries; i++) {
      io.FileSystemEntity entity = entries[i];
      if (entity is io.Directory) {
        children.add(new _PhysicalFolder(entity));
      } else if (entity is io.File) {
        children.add(new _PhysicalFile(entity));
      }
    }
    return children;
  }

  @override
  bool isOrContains(String path) {
    if (path == this.path) {
      return true;
    }
    return contains(path);
  }
}


/**
 * A `dart:io` based implementation of [Resource].
 */
abstract class _PhysicalResource implements Resource {
  final io.FileSystemEntity _entry;

  _PhysicalResource(this._entry);

  @override
  bool get exists => _entry.existsSync();

  @override
  get hashCode => path.hashCode;

  @override
  Folder get parent {
    String parentPath = dirname(path);
    if (parentPath == path) {
      return null;
    }
    return new _PhysicalFolder(new io.Directory(parentPath));
  }

  @override
  String get path => _entry.absolute.path;

  @override
  String get shortName => basename(path);

  @override
  bool operator ==(other) {
    if (runtimeType != other.runtimeType) {
      return false;
    }
    return path == other.path;
  }

  @override
  String toString() => path;
}
