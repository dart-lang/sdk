// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.file_system.memory_file_system;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:core';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/source/source_resource.dart';
import 'package:path/path.dart' as pathos;
import 'package:watcher/watcher.dart';

/**
 * An in-memory implementation of [ResourceProvider].
 * Use `/` as a path separator.
 */
class MemoryResourceProvider implements ResourceProvider {
  final Map<String, _MemoryResource> _pathToResource =
      new HashMap<String, _MemoryResource>();
  final Map<String, List<int>> _pathToBytes = new HashMap<String, List<int>>();
  final Map<String, int> _pathToTimestamp = new HashMap<String, int>();
  final Map<String, List<StreamController<WatchEvent>>> _pathToWatchers =
      new HashMap<String, List<StreamController<WatchEvent>>>();
  int nextStamp = 0;

  final pathos.Context _pathContext;

  MemoryResourceProvider(
      {pathos.Context context, @deprecated bool isWindows: false})
      : _pathContext = (context ??= pathos.style == pathos.Style.windows
            // On Windows, ensure that the current drive matches
            // the drive inserted by MemoryResourceProvider.convertPath
            // so that packages are mapped to the correct drive
            ? new pathos.Context(current: 'C:\\')
            : pathos.context);

  @override
  pathos.Context get pathContext => _pathContext;

  /**
   * Convert the given posix [path] to conform to this provider's path context.
   *
   * This is a utility method for testing; paths passed in to other methods in
   * this class are never converted automatically.
   */
  String convertPath(String path) {
    if (pathContext.style == pathos.windows.style) {
      if (path.startsWith(pathos.posix.separator)) {
        path = r'C:' + path;
      }
      path = path.replaceAll(pathos.posix.separator, pathos.windows.separator);
    }
    return path;
  }

  /**
   * Delete the file with the given path.
   */
  void deleteFile(String path) {
    _checkFileAtPath(path);
    _pathToResource.remove(path);
    _pathToBytes.remove(path);
    _pathToTimestamp.remove(path);
    _notifyWatchers(path, ChangeType.REMOVE);
  }

  /**
   * Delete the folder with the given path
   * and recursively delete nested files and folders.
   */
  void deleteFolder(String path) {
    _checkFolderAtPath(path);
    _MemoryFolder folder = _pathToResource[path];
    for (Resource child in folder.getChildren()) {
      if (child is File) {
        deleteFile(child.path);
      } else if (child is Folder) {
        deleteFolder(child.path);
      } else {
        throw 'failed to delete resource: $child';
      }
    }
    _pathToResource.remove(path);
    _pathToBytes.remove(path);
    _pathToTimestamp.remove(path);
    _notifyWatchers(path, ChangeType.REMOVE);
  }

  @override
  File getFile(String path) => new _MemoryFile(this, path);

  @override
  Folder getFolder(String path) {
    path = pathContext.normalize(path);
    if (!pathContext.isAbsolute(path)) {
      throw new ArgumentError("Path must be absolute : $path");
    }
    return new _MemoryFolder(this, path);
  }

  @override
  Future<List<int>> getModificationTimes(List<Source> sources) async {
    return sources.map((source) {
      String path = source.fullName;
      return _pathToTimestamp[path] ?? -1;
    }).toList();
  }

  @override
  Resource getResource(String path) {
    path = pathContext.normalize(path);
    Resource resource = _pathToResource[path];
    if (resource == null) {
      resource = new _MemoryFile(this, path);
    }
    return resource;
  }

  @override
  Folder getStateLocation(String pluginId) {
    return newFolder('/user/home/$pluginId');
  }

  void modifyFile(String path, String content) {
    _checkFileAtPath(path);
    _pathToBytes[path] = utf8.encode(content);
    _pathToTimestamp[path] = nextStamp++;
    _notifyWatchers(path, ChangeType.MODIFY);
  }

  /**
   * Create a resource representing a dummy link (that is, a File object which
   * appears in its parent directory, but whose `exists` property is false)
   */
  File newDummyLink(String path) {
    path = pathContext.normalize(path);
    newFolder(pathContext.dirname(path));
    _MemoryDummyLink link = new _MemoryDummyLink(this, path);
    _pathToResource[path] = link;
    _pathToTimestamp[path] = nextStamp++;
    _notifyWatchers(path, ChangeType.ADD);
    return link;
  }

  File newFile(String path, String content, [int stamp]) {
    path = pathContext.normalize(path);
    _MemoryFile file = _newFile(path);
    _pathToBytes[path] = utf8.encode(content);
    _pathToTimestamp[path] = stamp ?? nextStamp++;
    _notifyWatchers(path, ChangeType.ADD);
    return file;
  }

  File newFileWithBytes(String path, List<int> bytes, [int stamp]) {
    path = pathContext.normalize(path);
    _MemoryFile file = _newFile(path);
    _pathToBytes[path] = bytes;
    _pathToTimestamp[path] = stamp ?? nextStamp++;
    _notifyWatchers(path, ChangeType.ADD);
    return file;
  }

  Folder newFolder(String path) {
    path = pathContext.normalize(path);
    if (!pathContext.isAbsolute(path)) {
      throw new ArgumentError("Path must be absolute : $path");
    }
    _MemoryResource resource = _pathToResource[path];
    if (resource == null) {
      String parentPath = pathContext.dirname(path);
      if (parentPath != path) {
        newFolder(parentPath);
      }
      _MemoryFolder folder = new _MemoryFolder(this, path);
      _pathToResource[path] = folder;
      _pathToTimestamp[path] = nextStamp++;
      _notifyWatchers(path, ChangeType.ADD);
      return folder;
    } else if (resource is _MemoryFolder) {
      _notifyWatchers(path, ChangeType.ADD);
      return resource;
    } else {
      String message =
          'Folder expected at ' "'$path'" 'but ${resource.runtimeType} found';
      throw new ArgumentError(message);
    }
  }

  File updateFile(String path, String content, [int stamp]) {
    path = pathContext.normalize(path);
    newFolder(pathContext.dirname(path));
    _MemoryFile file = new _MemoryFile(this, path);
    _pathToResource[path] = file;
    _pathToBytes[path] = utf8.encode(content);
    _pathToTimestamp[path] = stamp ?? nextStamp++;
    _notifyWatchers(path, ChangeType.MODIFY);
    return file;
  }

  /**
   * Write a representation of the file system on the given [sink].
   */
  void writeOn(StringSink sink) {
    List<String> paths = _pathToResource.keys.toList();
    paths.sort();
    paths.forEach(sink.writeln);
  }

  void _checkFileAtPath(String path) {
    _MemoryResource resource = _pathToResource[path];
    if (resource is! _MemoryFile) {
      if (resource == null) {
        throw new ArgumentError('File expected at "$path" but does not exist');
      }
      throw new ArgumentError(
          'File expected at "$path" but ${resource.runtimeType} found');
    }
  }

  void _checkFolderAtPath(String path) {
    _MemoryResource resource = _pathToResource[path];
    if (resource is! _MemoryFolder) {
      throw new ArgumentError(
          'Folder expected at "$path" but ${resource.runtimeType} found');
    }
  }

  /**
   * Create a new [_MemoryFile] without any content.
   */
  _MemoryFile _newFile(String path) {
    String folderPath = pathContext.dirname(path);
    _MemoryResource folder = _pathToResource[folderPath];
    if (folder == null) {
      newFolder(folderPath);
    } else if (folder is! Folder) {
      throw new ArgumentError('Cannot create file ($path) as child of file');
    }
    _MemoryFile file = new _MemoryFile(this, path);
    _pathToResource[path] = file;
    return file;
  }

  void _notifyWatchers(String path, ChangeType changeType) {
    _pathToWatchers.forEach((String watcherPath,
        List<StreamController<WatchEvent>> streamControllers) {
      if (watcherPath == path || pathContext.isWithin(watcherPath, path)) {
        for (StreamController<WatchEvent> streamController
            in streamControllers) {
          streamController.add(new WatchEvent(changeType, path));
        }
      }
    });
  }

  _MemoryFile _renameFileSync(_MemoryFile file, String newPath) {
    String path = file.path;
    if (newPath == path) {
      return file;
    }
    _MemoryResource existingNewResource = _pathToResource[newPath];
    if (existingNewResource is _MemoryFolder) {
      throw new FileSystemException(
          path, 'Could not be renamed: $newPath is a folder.');
    }
    _MemoryFile newFile = _newFile(newPath);
    _pathToResource.remove(path);
    _pathToBytes[newPath] = _pathToBytes.remove(path);
    _pathToTimestamp[newPath] = _pathToTimestamp.remove(path);
    if (existingNewResource != null) {
      _notifyWatchers(newPath, ChangeType.REMOVE);
    }
    _notifyWatchers(path, ChangeType.REMOVE);
    _notifyWatchers(newPath, ChangeType.ADD);
    return newFile;
  }

  void _setFileContent(_MemoryFile file, List<int> bytes) {
    String path = file.path;
    _pathToResource[path] = file;
    _pathToBytes[path] = bytes;
    _pathToTimestamp[path] = nextStamp++;
    _notifyWatchers(path, ChangeType.MODIFY);
  }
}

/**
 * An in-memory implementation of [File] which acts like a symbolic link to a
 * non-existent file.
 */
class _MemoryDummyLink extends _MemoryResource implements File {
  _MemoryDummyLink(MemoryResourceProvider provider, String path)
      : super(provider, path);

  @override
  Stream<WatchEvent> get changes {
    throw new FileSystemException(path, "File does not exist");
  }

  @override
  bool get exists => false;

  @override
  int get lengthSync {
    throw new FileSystemException(path, 'File could not be read');
  }

  @override
  int get modificationStamp {
    int stamp = _provider._pathToTimestamp[path];
    if (stamp == null) {
      throw new FileSystemException(path, "File does not exist");
    }
    return stamp;
  }

  @override
  File copyTo(Folder parentFolder) {
    throw new FileSystemException(path, 'File could not be copied');
  }

  @override
  Source createSource([Uri uri]) {
    throw new FileSystemException(path, 'File could not be read');
  }

  @override
  void delete() {
    throw new FileSystemException(path, 'File could not be deleted');
  }

  @override
  bool isOrContains(String path) {
    return path == this.path;
  }

  @override
  List<int> readAsBytesSync() {
    throw new FileSystemException(path, 'File could not be read');
  }

  @override
  String readAsStringSync() {
    throw new FileSystemException(path, 'File could not be read');
  }

  @override
  File renameSync(String newPath) {
    throw new FileSystemException(path, 'File could not be renamed');
  }

  @override
  File resolveSymbolicLinksSync() {
    return throw new FileSystemException(path, "File does not exist");
  }

  @override
  void writeAsBytesSync(List<int> bytes) {
    throw new FileSystemException(path, 'File could not be written');
  }

  @override
  void writeAsStringSync(String content) {
    throw new FileSystemException(path, 'File could not be written');
  }
}

/**
 * An in-memory implementation of [File].
 */
class _MemoryFile extends _MemoryResource implements File {
  _MemoryFile(MemoryResourceProvider provider, String path)
      : super(provider, path);

  @override
  bool get exists => _provider._pathToResource[path] is _MemoryFile;

  @override
  int get lengthSync {
    return readAsBytesSync().length;
  }

  @override
  int get modificationStamp {
    int stamp = _provider._pathToTimestamp[path];
    if (stamp == null) {
      throw new FileSystemException(path, 'File "$path" does not exist.');
    }
    return stamp;
  }

  @override
  File copyTo(Folder parentFolder) {
    parentFolder.create();
    File destination = parentFolder.getChildAssumingFile(shortName);
    destination.writeAsBytesSync(readAsBytesSync());
    return destination;
  }

  @override
  Source createSource([Uri uri]) {
    uri ??= _provider.pathContext.toUri(path);
    return new FileSource(this, uri);
  }

  @override
  void delete() {
    _provider.deleteFile(path);
  }

  @override
  bool isOrContains(String path) {
    return path == this.path;
  }

  @override
  List<int> readAsBytesSync() {
    List<int> content = _provider._pathToBytes[path];
    if (content == null) {
      throw new FileSystemException(path, 'File "$path" does not exist.');
    }
    return content;
  }

  @override
  String readAsStringSync() {
    List<int> content = _provider._pathToBytes[path];
    if (content == null) {
      throw new FileSystemException(path, 'File "$path" does not exist.');
    }
    return utf8.decode(content);
  }

  @override
  File renameSync(String newPath) {
    return _provider._renameFileSync(this, newPath);
  }

  @override
  File resolveSymbolicLinksSync() => this;

  @override
  void writeAsBytesSync(List<int> bytes) {
    _provider._setFileContent(this, bytes);
  }

  @override
  void writeAsStringSync(String content) {
    _provider._setFileContent(this, utf8.encode(content));
  }
}

/**
 * An in-memory implementation of [Folder].
 */
class _MemoryFolder extends _MemoryResource implements Folder {
  _MemoryFolder(MemoryResourceProvider provider, String path)
      : super(provider, path);

  @override
  bool get exists => _provider._pathToResource[path] is _MemoryFolder;

  @override
  String canonicalizePath(String relPath) {
    relPath = _provider.pathContext.normalize(relPath);
    String childPath = _provider.pathContext.join(path, relPath);
    childPath = _provider.pathContext.normalize(childPath);
    return childPath;
  }

  @override
  bool contains(String path) {
    return _provider.pathContext.isWithin(this.path, path);
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
    _provider.newFolder(path);
  }

  @override
  void delete() {
    _provider.deleteFolder(path);
  }

  @override
  Resource getChild(String relPath) {
    String childPath = canonicalizePath(relPath);
    _MemoryResource resource = _provider._pathToResource[childPath];
    if (resource == null) {
      resource = new _MemoryFile(_provider, childPath);
    }
    return resource;
  }

  @override
  _MemoryFile getChildAssumingFile(String relPath) {
    String childPath = canonicalizePath(relPath);
    _MemoryResource resource = _provider._pathToResource[childPath];
    if (resource is _MemoryFile) {
      return resource;
    }
    return new _MemoryFile(_provider, childPath);
  }

  @override
  _MemoryFolder getChildAssumingFolder(String relPath) {
    String childPath = canonicalizePath(relPath);
    _MemoryResource resource = _provider._pathToResource[childPath];
    if (resource is _MemoryFolder) {
      return resource;
    }
    return new _MemoryFolder(_provider, childPath);
  }

  @override
  List<Resource> getChildren() {
    if (!exists) {
      throw new FileSystemException(path, 'Folder does not exist.');
    }
    List<Resource> children = <Resource>[];
    _provider._pathToResource.forEach((resourcePath, resource) {
      if (_provider.pathContext.dirname(resourcePath) == path) {
        children.add(resource);
      }
    });
    return children;
  }

  @override
  bool isOrContains(String path) {
    if (path == this.path) {
      return true;
    }
    return contains(path);
  }

  @override
  Folder resolveSymbolicLinksSync() => this;

  @override
  Uri toUri() => _provider.pathContext.toUri(path + '/');
}

/**
 * An in-memory implementation of [Resource].
 */
abstract class _MemoryResource implements Resource {
  final MemoryResourceProvider _provider;
  @override
  final String path;

  _MemoryResource(this._provider, this.path);

  Stream<WatchEvent> get changes {
    StreamController<WatchEvent> streamController =
        new StreamController<WatchEvent>();
    if (!_provider._pathToWatchers.containsKey(path)) {
      _provider._pathToWatchers[path] = <StreamController<WatchEvent>>[];
    }
    _provider._pathToWatchers[path].add(streamController);
    streamController.done.then((_) {
      _provider._pathToWatchers[path].remove(streamController);
      if (_provider._pathToWatchers[path].isEmpty) {
        _provider._pathToWatchers.remove(path);
      }
    });
    return streamController.stream;
  }

  @override
  get hashCode => path.hashCode;

  @override
  Folder get parent {
    String parentPath = _provider.pathContext.dirname(path);
    if (parentPath == path) {
      return null;
    }
    return _provider.getFolder(parentPath);
  }

  @override
  String get shortName => _provider.pathContext.basename(path);

  @override
  bool operator ==(other) {
    if (runtimeType != other.runtimeType) {
      return false;
    }
    return path == other.path;
  }

  @override
  String toString() => path;

  @override
  Uri toUri() => _provider.pathContext.toUri(path);
}
