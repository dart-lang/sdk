// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library physical_file_system;

import 'dart:async';
import 'dart:core' hide Resource;
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
  static final NORMALIZE_EOL_ALWAYS = (String string) =>
      string.replaceAll(new RegExp('\r\n?'), '\n');

  static final PhysicalResourceProvider INSTANCE =
      new PhysicalResourceProvider(null);

  /**
   * The name of the directory containing plugin specific subfolders used to
   * store data across sessions.
   */
  static final String SERVER_DIR = ".dartServer";

  PhysicalResourceProvider(String fileReadMode(String s)) {
    if (fileReadMode != null) {
      FileBasedSource.fileReadMode = fileReadMode;
    }
  }

  @override
  Context get pathContext => io.Platform.isWindows ? windows : posix;

  @override
  File getFile(String path) => new _PhysicalFile(new io.File(path));

  @override
  Folder getFolder(String path) => new _PhysicalFolder(new io.Directory(path));

  @override
  Resource getResource(String path) {
    if (io.FileSystemEntity.isDirectorySync(path)) {
      return getFolder(path);
    } else {
      return getFile(path);
    }
  }

  @override
  Folder getStateLocation(String pluginId) {
    String home;
    if (io.Platform.isWindows) {
      home = io.Platform.environment['LOCALAPPDATA'];
    } else {
      home = io.Platform.environment['HOME'];
    }
    if (home != null && io.FileSystemEntity.isDirectorySync(home)) {
      io.Directory directory =
          new io.Directory(join(home, SERVER_DIR, pluginId));
      directory.createSync(recursive: true);
      return new _PhysicalFolder(directory);
    }
    return null;
  }
}

/**
 * A `dart:io` based implementation of [File].
 */
class _PhysicalFile extends _PhysicalResource implements File {
  _PhysicalFile(io.File file) : super(file);

  @override
  Stream<WatchEvent> get changes => new FileWatcher(_entry.path).events;

  @override
  int get modificationStamp {
    try {
      io.File file = _entry as io.File;
      return file.lastModifiedSync().millisecondsSinceEpoch;
    } on io.FileSystemException catch (exception) {
      throw new FileSystemException(exception.path, exception.message);
    }
  }

  @override
  Source createSource([Uri uri]) {
    io.File file = _entry as io.File;
    JavaFile javaFile = new JavaFile(file.absolute.path);
    if (uri == null) {
      uri = javaFile.toURI();
    }
    return new FileBasedSource(javaFile, uri);
  }

  @override
  bool isOrContains(String path) {
    return path == this.path;
  }

  @override
  String readAsStringSync() {
    try {
      io.File file = _entry as io.File;
      return file.readAsStringSync();
    } on io.FileSystemException catch (exception) {
      throw new FileSystemException(exception.path, exception.message);
    }
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
  _PhysicalFolder getChildAssumingFolder(String relPath) {
    String canonicalPath = canonicalizePath(relPath);
    io.Directory directory = new io.Directory(canonicalPath);
    return new _PhysicalFolder(directory);
  }

  @override
  List<Resource> getChildren() {
    try {
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
    } on io.FileSystemException catch (exception) {
      throw new FileSystemException(exception.path, exception.message);
    }
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
