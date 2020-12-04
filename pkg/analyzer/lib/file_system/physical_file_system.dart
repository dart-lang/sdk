// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;
import 'dart:typed_data';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/source/source_resource.dart';
import 'package:path/path.dart';
import 'package:watcher/watcher.dart';

/// The name of the directory containing plugin specific subfolders used to
/// store data across sessions.
const String _SERVER_DIR = ".dartServer";

/// Returns the path to default state location.
///
/// Generally this is ~/.dartServer. It can be overridden via the
/// ANALYZER_STATE_LOCATION_OVERRIDE environment variable, in which case this
/// method will return the contents of that environment variable.
String _getStandardStateLocation() {
  final Map<String, String> env = io.Platform.environment;
  if (env.containsKey('ANALYZER_STATE_LOCATION_OVERRIDE')) {
    return env['ANALYZER_STATE_LOCATION_OVERRIDE'];
  }

  final home = io.Platform.isWindows ? env['LOCALAPPDATA'] : env['HOME'];
  return home != null && io.FileSystemEntity.isDirectorySync(home)
      ? join(home, _SERVER_DIR)
      : null;
}

/// Return modification times for every file path in [paths].
///
/// If a path is `null`, the modification time is also `null`.
///
/// If any exception happens, the file is considered as a not existing and
/// `-1` is its modification time.
List<int> _pathsToTimes(List<String> paths) {
  return paths.map((path) {
    if (path != null) {
      try {
        io.File file = io.File(path);
        return file.lastModifiedSync().millisecondsSinceEpoch;
      } catch (_) {
        return -1;
      }
    } else {
      return null;
    }
  }).toList();
}

/// A `dart:io` based implementation of [ResourceProvider].
class PhysicalResourceProvider implements ResourceProvider {
  static final PhysicalResourceProvider INSTANCE = PhysicalResourceProvider();

  /// The path to the base folder where state is stored.
  final String _stateLocation;

  PhysicalResourceProvider({String stateLocation})
      : _stateLocation = stateLocation ?? _getStandardStateLocation();

  @override
  Context get pathContext => context;

  @override
  File getFile(String path) {
    _ensureAbsoluteAndNormalized(path);
    return _PhysicalFile(io.File(path));
  }

  @override
  Folder getFolder(String path) {
    _ensureAbsoluteAndNormalized(path);
    return _PhysicalFolder(io.Directory(path));
  }

  @override
  Future<List<int>> getModificationTimes(List<Source> sources) async {
    List<String> paths = sources.map((source) => source.fullName).toList();
    return _pathsToTimes(paths);
  }

  @override
  Resource getResource(String path) {
    _ensureAbsoluteAndNormalized(path);
    if (io.FileSystemEntity.isDirectorySync(path)) {
      return getFolder(path);
    } else {
      return getFile(path);
    }
  }

  @override
  Folder getStateLocation(String pluginId) {
    if (_stateLocation != null) {
      io.Directory directory = io.Directory(join(_stateLocation, pluginId));
      directory.createSync(recursive: true);
      return _PhysicalFolder(directory);
    }
    return null;
  }

  /// The file system abstraction supports only absolute and normalized paths.
  /// This method is used to validate any input paths to prevent errors later.
  void _ensureAbsoluteAndNormalized(String path) {
    assert(() {
      if (!pathContext.isAbsolute(path)) {
        throw ArgumentError("Path must be absolute : $path");
      }
      if (pathContext.normalize(path) != path) {
        throw ArgumentError("Path must be normalized : $path");
      }
      return true;
    }());
  }
}

/// A `dart:io` based implementation of [File].
class _PhysicalFile extends _PhysicalResource implements File {
  _PhysicalFile(io.File file) : super(file);

  @override
  Stream<WatchEvent> get changes => FileWatcher(_entry.path).events;

  @override
  int get lengthSync {
    try {
      return _file.lengthSync();
    } on io.FileSystemException catch (exception) {
      throw FileSystemException(exception.path, exception.message);
    }
  }

  @override
  int get modificationStamp {
    try {
      return _file.lastModifiedSync().millisecondsSinceEpoch;
    } on io.FileSystemException catch (exception) {
      throw FileSystemException(exception.path, exception.message);
    }
  }

  /// Return the underlying file being represented by this wrapper.
  io.File get _file => _entry as io.File;

  @override
  File copyTo(Folder parentFolder) {
    parentFolder.create();
    File destination = parentFolder.getChildAssumingFile(shortName);
    destination.writeAsBytesSync(readAsBytesSync());
    return destination;
  }

  @override
  Source createSource([Uri uri]) {
    return FileSource(this, uri ?? pathContext.toUri(path));
  }

  @override
  bool isOrContains(String path) {
    return path == this.path;
  }

  @override
  Uint8List readAsBytesSync() {
    _throwIfWindowsDeviceDriver();
    try {
      return _file.readAsBytesSync();
    } on io.FileSystemException catch (exception) {
      throw FileSystemException(exception.path, exception.message);
    }
  }

  @override
  String readAsStringSync() {
    _throwIfWindowsDeviceDriver();
    try {
      return _file.readAsStringSync();
    } on io.FileSystemException catch (exception) {
      throw FileSystemException(exception.path, exception.message);
    }
  }

  @override
  File renameSync(String newPath) {
    try {
      return _PhysicalFile(_file.renameSync(newPath));
    } on io.FileSystemException catch (exception) {
      throw FileSystemException(exception.path, exception.message);
    }
  }

  @override
  File resolveSymbolicLinksSync() {
    try {
      return _PhysicalFile(io.File(_file.resolveSymbolicLinksSync()));
    } on io.FileSystemException catch (exception) {
      throw FileSystemException(exception.path, exception.message);
    }
  }

  @override
  Uri toUri() => Uri.file(path);

  @override
  void writeAsBytesSync(List<int> bytes) {
    try {
      _file.writeAsBytesSync(bytes);
    } on io.FileSystemException catch (exception) {
      throw FileSystemException(exception.path, exception.message);
    }
  }

  @override
  void writeAsStringSync(String content) {
    try {
      _file.writeAsStringSync(content);
    } on io.FileSystemException catch (exception) {
      throw FileSystemException(exception.path, exception.message);
    }
  }
}

/// A `dart:io` based implementation of [Folder].
class _PhysicalFolder extends _PhysicalResource implements Folder {
  _PhysicalFolder(io.Directory directory) : super(directory);

  @override
  Stream<WatchEvent> get changes =>
      DirectoryWatcher(_entry.path).events.handleError((Object error) {},
          test: (error) =>
              error is io.FileSystemException &&
              // Don't suppress "Directory watcher closed," so the outer
              // listener can see the interruption & act on it.
              !error.message
                  .startsWith("Directory watcher closed unexpectedly"));

  /// Return the underlying file being represented by this wrapper.
  io.Directory get _directory => _entry as io.Directory;

  @override
  String canonicalizePath(String relPath) {
    return normalize(join(path, relPath));
  }

  @override
  bool contains(String path) {
    PhysicalResourceProvider.INSTANCE._ensureAbsoluteAndNormalized(path);
    return pathContext.isWithin(this.path, path);
  }

  @override
  Folder copyTo(Folder parentFolder) {
    Folder destination = parentFolder.getChildAssumingFolder(shortName);
    destination.create();
    for (Resource child in getChildren()) {
      child.copyTo(destination);
    }
    return destination;
  }

  @override
  void create() {
    _directory.createSync(recursive: true);
  }

  @override
  Resource getChild(String relPath) {
    String canonicalPath = canonicalizePath(relPath);
    return PhysicalResourceProvider.INSTANCE.getResource(canonicalPath);
  }

  @override
  _PhysicalFile getChildAssumingFile(String relPath) {
    String canonicalPath = canonicalizePath(relPath);
    io.File file = io.File(canonicalPath);
    return _PhysicalFile(file);
  }

  @override
  _PhysicalFolder getChildAssumingFolder(String relPath) {
    String canonicalPath = canonicalizePath(relPath);
    io.Directory directory = io.Directory(canonicalPath);
    return _PhysicalFolder(directory);
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
          children.add(_PhysicalFolder(entity));
        } else if (entity is io.File) {
          children.add(_PhysicalFile(entity));
        }
      }
      return children;
    } on io.FileSystemException catch (exception) {
      throw FileSystemException(exception.path, exception.message);
    }
  }

  @override
  bool isOrContains(String path) {
    if (path == this.path) {
      return true;
    }
    return contains(path);
  }

  @override
  Folder resolveSymbolicLinksSync() {
    try {
      return _PhysicalFolder(
          io.Directory(_directory.resolveSymbolicLinksSync()));
    } on io.FileSystemException catch (exception) {
      throw FileSystemException(exception.path, exception.message);
    }
  }

  @override
  Uri toUri() => Uri.directory(path);
}

/// A `dart:io` based implementation of [Resource].
abstract class _PhysicalResource implements Resource {
  final io.FileSystemEntity _entry;

  _PhysicalResource(this._entry);

  @override
  bool get exists {
    try {
      return _entry.existsSync();
    } on FileSystemException {
      return false;
    }
  }

  @override
  int get hashCode => path.hashCode;

  @override
  Folder get parent {
    String parentPath = pathContext.dirname(path);
    if (parentPath == path) {
      return null;
    }
    return _PhysicalFolder(io.Directory(parentPath));
  }

  @override
  String get path => _entry.path;

  /// Return the path context used by this resource provider.
  Context get pathContext => io.Platform.isWindows ? windows : posix;

  @override
  ResourceProvider get provider => PhysicalResourceProvider.INSTANCE;

  @override
  String get shortName => pathContext.basename(path);

  @override
  bool operator ==(Object other) {
    if (runtimeType != other.runtimeType) {
      return false;
    }
    return path == (other as _PhysicalResource).path;
  }

  @override
  void delete() {
    try {
      _entry.deleteSync(recursive: true);
    } on io.FileSystemException catch (exception) {
      throw FileSystemException(exception.path, exception.message);
    }
  }

  @override
  String toString() => path;

  /// If the operating system is Windows and the resource references one of the
  /// device drivers, throw a [FileSystemException].
  ///
  /// https://support.microsoft.com/en-us/kb/74496
  void _throwIfWindowsDeviceDriver() {
    if (io.Platform.isWindows) {
      String shortName = this.shortName.toUpperCase();
      if (shortName == r'CON' ||
          shortName == r'PRN' ||
          shortName == r'AUX' ||
          shortName == r'CLOCK$' ||
          shortName == r'NUL' ||
          shortName == r'COM1' ||
          shortName == r'LPT1' ||
          shortName == r'LPT2' ||
          shortName == r'LPT3' ||
          shortName == r'COM2' ||
          shortName == r'COM3' ||
          shortName == r'COM4') {
        throw FileSystemException(
            path, 'Windows device drivers cannot be read.');
      }
    }
  }
}
