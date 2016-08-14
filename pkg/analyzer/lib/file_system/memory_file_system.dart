// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.file_system.memory_file_system;

import 'dart:async';
import 'dart:collection';
import 'dart:core' hide Resource;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart' show TimestampedData;
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/util/absolute_path.dart';
import 'package:path/path.dart';
import 'package:watcher/watcher.dart';

/**
 * An in-memory implementation of [ResourceProvider].
 * Use `/` as a path separator.
 */
class MemoryResourceProvider implements ResourceProvider {
  final Map<String, _MemoryResource> _pathToResource =
      new HashMap<String, _MemoryResource>();
  final Map<String, String> _pathToContent = new HashMap<String, String>();
  final Map<String, List<int>> _pathToBytes = new HashMap<String, List<int>>();
  final Map<String, int> _pathToTimestamp = new HashMap<String, int>();
  final Map<String, List<StreamController<WatchEvent>>> _pathToWatchers =
      new HashMap<String, List<StreamController<WatchEvent>>>();
  int nextStamp = 0;

  final Context _pathContext;
  @override
  final AbsolutePathContext absolutePathContext;

  MemoryResourceProvider({bool isWindows: false})
      : _pathContext = isWindows ? windows : posix,
        absolutePathContext = new AbsolutePathContext(isWindows);

  @override
  Context get pathContext => _pathContext;

  /**
   * Delete the file with the given path.
   */
  void deleteFile(String path) {
    _checkFileAtPath(path);
    _pathToResource.remove(path);
    _pathToContent.remove(path);
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
    _pathToContent.remove(path);
    _pathToTimestamp.remove(path);
    _notifyWatchers(path, ChangeType.REMOVE);
  }

  @override
  File getFile(String path) => new _MemoryFile(this, path);

  @override
  Folder getFolder(String path) => newFolder(path);

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
    _pathToContent[path] = content;
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
    _pathToContent[path] = content;
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

  _MemoryFile renameFileSync(_MemoryFile file, String newPath) {
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
    _pathToContent[newPath] = _pathToContent.remove(path);
    _pathToBytes[newPath] = _pathToBytes.remove(path);
    _pathToTimestamp[newPath] = _pathToTimestamp.remove(path);
    if (existingNewResource != null) {
      _notifyWatchers(newPath, ChangeType.REMOVE);
    }
    _notifyWatchers(path, ChangeType.REMOVE);
    _notifyWatchers(newPath, ChangeType.ADD);
    return newFile;
  }

  File updateFile(String path, String content, [int stamp]) {
    path = pathContext.normalize(path);
    newFolder(pathContext.dirname(path));
    _MemoryFile file = new _MemoryFile(this, path);
    _pathToResource[path] = file;
    _pathToContent[path] = content;
    _pathToTimestamp[path] = stamp ?? nextStamp++;
    _notifyWatchers(path, ChangeType.MODIFY);
    return file;
  }

  void _checkFileAtPath(String path) {
    _MemoryResource resource = _pathToResource[path];
    if (resource is! _MemoryFile) {
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

  void _setFileBytes(_MemoryFile file, List<int> bytes) {
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
  int get modificationStamp {
    int stamp = _provider._pathToTimestamp[path];
    if (stamp == null) {
      throw new FileSystemException(path, "File does not exist");
    }
    return stamp;
  }

  String get _content {
    throw new FileSystemException(path, 'File could not be read');
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
  Uri toUri() => new Uri.file(path, windows: _provider.pathContext == windows);

  @override
  void writeAsBytesSync(List<int> bytes) {
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
  int get modificationStamp {
    int stamp = _provider._pathToTimestamp[path];
    if (stamp == null) {
      throw new FileSystemException(path, 'File "$path" does not exist.');
    }
    return stamp;
  }

  String get _content {
    String content = _provider._pathToContent[path];
    if (content == null) {
      throw new FileSystemException(path, 'File "$path" does not exist.');
    }
    return content;
  }

  @override
  Source createSource([Uri uri]) {
    if (uri == null) {
      uri = _provider.pathContext.toUri(path);
    }
    return new _MemoryFileSource(this, uri);
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
    List<int> bytes = _provider._pathToBytes[path];
    if (bytes == null) {
      throw new FileSystemException(path, 'File "$path" is not binary.');
    }
    return bytes;
  }

  @override
  String readAsStringSync() {
    String content = _provider._pathToContent[path];
    if (content == null) {
      throw new FileSystemException(path, 'File "$path" does not exist.');
    }
    return content;
  }

  @override
  File renameSync(String newPath) {
    return _provider.renameFileSync(this, newPath);
  }

  @override
  Uri toUri() => new Uri.file(path, windows: _provider.pathContext == windows);

  @override
  void writeAsBytesSync(List<int> bytes) {
    _provider._setFileBytes(this, bytes);
  }
}

/**
 * An in-memory implementation of [Source].
 */
class _MemoryFileSource extends Source {
  /**
   * Map from encoded URI/filepath pair to a unique integer identifier.  This
   * identifier is used for equality tests and hash codes.
   *
   * The URI and filepath are joined into a pair by separating them with an '@'
   * character.
   */
  static final Map<String, int> _idTable = new HashMap<String, int>();

  final _MemoryFile file;

  @override
  final Uri uri;

  /**
   * The unique ID associated with this [_MemoryFileSource].
   */
  final int id;

  _MemoryFileSource(_MemoryFile file, Uri uri)
      : uri = uri,
        file = file,
        id = _idTable.putIfAbsent('$uri@${file.path}', () => _idTable.length);

  @override
  TimestampedData<String> get contents {
    return new TimestampedData<String>(modificationStamp, file._content);
  }

  @override
  String get encoding {
    return uri.toString();
  }

  @override
  String get fullName => file.path;

  @override
  int get hashCode => id;

  @override
  bool get isInSystemLibrary => uriKind == UriKind.DART_URI;

  @override
  int get modificationStamp {
    try {
      return file.modificationStamp;
    } on FileSystemException {
      return -1;
    }
  }

  @override
  String get shortName => file.shortName;

  @override
  UriKind get uriKind {
    String scheme = uri.scheme;
    if (scheme == PackageUriResolver.PACKAGE_SCHEME) {
      return UriKind.PACKAGE_URI;
    } else if (scheme == DartUriResolver.DART_SCHEME) {
      return UriKind.DART_URI;
    } else if (scheme == ResourceUriResolver.FILE_SCHEME) {
      return UriKind.FILE_URI;
    }
    return UriKind.FILE_URI;
  }

  @override
  bool operator ==(other) {
    if (other is _MemoryFileSource) {
      return id == other.id;
    } else if (other is Source) {
      return uri == other.uri;
    }
    return false;
  }

  @override
  bool exists() => file.exists;

  @override
  String toString() => file.toString();
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
  Uri toUri() =>
      new Uri.directory(path, windows: _provider.pathContext == windows);
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
    return _provider.getResource(parentPath);
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
}
